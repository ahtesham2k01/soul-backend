<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\SupportTicketAttachment;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class SupportAttachmentController extends Controller
{
    public function store(Request $request, string $ticket): JsonResponse
    {
        $validated = $request->validate(['file' => ['required', 'file', 'max:'.config('soul.support.max_attachment_kilobytes'), 'mimes:jpg,jpeg,png,pdf']]);
        $record = $request->user()->supportTickets()->where('public_id', $ticket)->first();
        if (! $record) {
            return ApiResponse::error('SUPPORT_TICKET_NOT_FOUND', 'Support ticket not found.', 404);
        }
        if (in_array($record->status, ['closed', 'resolved'], true)) {
            return ApiResponse::error('SUPPORT_TICKET_CLOSED', 'This support ticket is closed.', 409);
        }
        $message = $record->messages()->where('sender_user_id', $request->user()->id)->latest('id')->first();
        if (! $message || $message->attachments()->count() >= 3) {
            return ApiResponse::error('ATTACHMENT_LIMIT_REACHED', 'A message can have up to three attachments.', 422);
        }
        $file = $validated['file'];
        $disk = config('soul.support.attachment_disk', 'local');
        $path = $file->store('support/'.$request->user()->public_id.'/'.$record->public_id, $disk);
        $attachment = $message->attachments()->create(['disk' => $disk, 'path' => $path,
            'original_name' => $file->getClientOriginalName(), 'mime_type' => $file->getMimeType(),
            'size_bytes' => $file->getSize(), 'sha256' => hash_file('sha256', $file->getRealPath())]);

        return ApiResponse::success(['attachment' => ['id' => $attachment->public_id, 'name' => $attachment->original_name]], 'Attachment uploaded.', 201);
    }

    public function show(Request $request, string $attachment): StreamedResponse|JsonResponse
    {
        $record = SupportTicketAttachment::query()->where('public_id', $attachment)
            ->whereHas('message.ticket', fn ($query) => $query->where('user_id', $request->user()->id))->first();
        if (! $record || ! Storage::disk($record->disk)->exists($record->path)) {
            return ApiResponse::error('ATTACHMENT_NOT_FOUND', 'Attachment not found.', 404);
        }

        return Storage::disk($record->disk)->download($record->path, $record->original_name, ['Content-Type' => $record->mime_type]);
    }
}
