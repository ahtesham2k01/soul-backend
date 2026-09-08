<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\SupportTicket;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class SupportTicketController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate(['status' => ['nullable', Rule::in(['open', 'waiting_for_support', 'waiting_for_member', 'resolved', 'closed'])]]);
        $query = SupportTicket::with(['user', 'category.translations'])->latest('last_message_at');
        if (isset($validated['status'])) {
            $query->where('status', $validated['status']);
        }
        $page = $query->cursorPaginate(50);

        return ApiResponse::success(['tickets' => collect($page->items())->map(fn ($ticket) => $this->summary($ticket)), 'next_cursor' => $page->nextCursor()?->encode()]);
    }

    public function show(string $ticket): JsonResponse
    {
        $record = SupportTicket::where('public_id', $ticket)->with(['user', 'category.translations', 'messages.attachments'])->first();
        if (! $record) {
            return ApiResponse::error('SUPPORT_TICKET_NOT_FOUND', 'Support ticket not found.', 404);
        }

        return ApiResponse::success(['ticket' => [...$this->summary($record), 'messages' => $record->messages->map(fn ($message) => ['id' => $message->public_id, 'sender' => $message->sender_role, 'body' => $message->body, 'is_internal' => $message->is_internal, 'sent_at' => $message->created_at->toIso8601String()])]]);
    }

    public function update(Request $request, string $ticket): JsonResponse
    {
        $record = SupportTicket::where('public_id', $ticket)->first();
        if (! $record) {
            return ApiResponse::error('SUPPORT_TICKET_NOT_FOUND', 'Support ticket not found.', 404);
        }
        $data = $request->validate(['status' => ['sometimes', Rule::in(['open', 'waiting_for_support', 'waiting_for_member', 'resolved', 'closed'])], 'priority' => ['sometimes', Rule::in(['low', 'normal', 'high', 'urgent'])], 'message' => ['nullable', 'string', 'max:5000', 'regex:/\S/'], 'internal_note' => ['nullable', 'string', 'max:5000', 'regex:/\S/'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $before = $record->only(['status', 'priority', 'assigned_admin_id', 'closed_at']);
        DB::transaction(function () use ($request, $record, $data): void {
            if (! empty($data['message'])) {
                $record->messages()->create(['sender_user_id' => $request->user()->id, 'sender_role' => 'support', 'body' => trim($data['message']), 'is_internal' => false]);
            }
            if (! empty($data['internal_note'])) {
                $record->messages()->create(['sender_user_id' => $request->user()->id, 'sender_role' => 'support', 'body' => trim($data['internal_note']), 'is_internal' => true]);
            }
            $status = $data['status'] ?? (! empty($data['message']) ? 'waiting_for_member' : $record->status);
            $record->update(['status' => $status, 'priority' => $data['priority'] ?? $record->priority, 'assigned_admin_id' => $request->user()->id, 'last_message_at' => now(), 'closed_at' => in_array($status, ['resolved', 'closed'], true) ? now() : null]);
        });
        AdminAuditLog::create(['admin_user_id' => $request->user()->id, 'action' => 'support_ticket.updated', 'subject_type' => SupportTicket::class, 'subject_id' => $record->id, 'before' => $before, 'after' => $record->only(['status', 'priority', 'assigned_admin_id', 'closed_at']), 'reason' => $data['reason'], 'ip_address' => $request->ip()]);

        return ApiResponse::success(['ticket' => $this->summary($record->load('user', 'category.translations'))]);
    }

    private function summary($ticket): array
    {
        return ['id' => $ticket->public_id, 'subject' => $ticket->subject, 'status' => $ticket->status, 'priority' => $ticket->priority, 'member' => ['id' => $ticket->user->public_id, 'email' => $ticket->user->email], 'category_key' => $ticket->category?->key, 'last_message_at' => $ticket->last_message_at->toIso8601String()];
    }
}
