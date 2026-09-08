<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HelpCategory;
use App\Models\SupportTicket;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SupportTicketController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $page = $request->user()->supportTickets()->with('category.translations')
            ->latest('last_message_at')->cursorPaginate(20);

        return ApiResponse::success([
            'tickets' => collect($page->items())->map(fn (SupportTicket $ticket) => $this->summary($ticket)),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'category_id' => ['required', 'string'],
            'subject' => ['required', 'string', 'max:160', 'regex:/\S/'],
            'message' => ['required', 'string', 'max:5000', 'regex:/\S/'],
        ]);
        $category = HelpCategory::query()->where('public_id', $validated['category_id'])->where('is_active', true)->first();
        if (! $category) {
            return ApiResponse::error('HELP_CATEGORY_NOT_FOUND', 'Help category is unavailable.', 422);
        }
        $ticket = DB::transaction(function () use ($request, $validated, $category): SupportTicket {
            $ticket = $request->user()->supportTickets()->create([
                'help_category_id' => $category->id,
                'subject' => trim($validated['subject']),
                'status' => 'open', 'priority' => 'normal', 'last_message_at' => now(),
            ]);
            $ticket->messages()->create([
                'sender_user_id' => $request->user()->id, 'sender_role' => 'member',
                'body' => trim($validated['message']), 'is_internal' => false,
            ]);

            return $ticket;
        });

        return ApiResponse::success(['ticket' => $this->detail($ticket->load('messages.attachments', 'category.translations'))], 'Support ticket created.', 201);
    }

    public function show(Request $request, string $ticket): JsonResponse
    {
        $record = $request->user()->supportTickets()->where('public_id', $ticket)
            ->with(['category.translations', 'messages' => fn ($query) => $query->where('is_internal', false)->with('attachments')])->first();
        if (! $record) {
            return ApiResponse::error('SUPPORT_TICKET_NOT_FOUND', 'Support ticket not found.', 404);
        }

        return ApiResponse::success(['ticket' => $this->detail($record)]);
    }

    public function reply(Request $request, string $ticket): JsonResponse
    {
        $validated = $request->validate(['message' => ['required', 'string', 'max:5000', 'regex:/\S/']]);
        $record = $request->user()->supportTickets()->where('public_id', $ticket)->first();
        if (! $record) {
            return ApiResponse::error('SUPPORT_TICKET_NOT_FOUND', 'Support ticket not found.', 404);
        }
        if (in_array($record->status, ['closed', 'resolved'], true)) {
            return ApiResponse::error('SUPPORT_TICKET_CLOSED', 'This support ticket is closed.', 409);
        }
        $message = DB::transaction(function () use ($request, $record, $validated) {
            $message = $record->messages()->create([
                'sender_user_id' => $request->user()->id, 'sender_role' => 'member',
                'body' => trim($validated['message']), 'is_internal' => false,
            ]);
            $record->update(['status' => 'waiting_for_support', 'last_message_at' => $message->created_at]);

            return $message;
        });

        return ApiResponse::success(['message' => $this->message($message)], 'Reply added.', 201);
    }

    private function summary(SupportTicket $ticket): array
    {
        return ['id' => $ticket->public_id, 'subject' => $ticket->subject, 'status' => $ticket->status,
            'priority' => $ticket->priority, 'category_key' => $ticket->category?->key,
            'last_message_at' => $ticket->last_message_at->toIso8601String()];
    }

    private function detail(SupportTicket $ticket): array
    {
        return [...$this->summary($ticket), 'messages' => $ticket->messages->map(fn ($message) => $this->message($message))->values()];
    }

    private function message($message): array
    {
        return ['id' => $message->public_id, 'sender' => $message->sender_role, 'body' => $message->body,
            'attachments' => $message->attachments->map(fn ($file) => ['id' => $file->public_id, 'name' => $file->original_name, 'mime_type' => $file->mime_type, 'size_bytes' => $file->size_bytes]),
            'sent_at' => $message->created_at->toIso8601String()];
    }
}
