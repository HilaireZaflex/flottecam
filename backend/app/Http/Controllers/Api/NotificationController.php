<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FcmToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $notifications = DB::table('notifications')
            ->where('notifiable_type', 'App\\Models\\User')
            ->where('notifiable_id', $request->user()->id)
            ->latest()
            ->paginate(20);

        return response()->json($notifications);
    }

    public function markAsRead(Request $request, string $id): JsonResponse
    {
        DB::table('notifications')
            ->where('id', $id)
            ->where('notifiable_id', $request->user()->id)
            ->update(['read_at' => now()]);
        return response()->json(['message' => 'Notification marked as read']);
    }

    public function readAll(Request $request): JsonResponse
    {
        DB::table('notifications')
            ->where('notifiable_type', 'App\\Models\\User')
            ->where('notifiable_id', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);
        return response()->json(['message' => 'All notifications marked as read']);
    }

    public function saveFcmToken(Request $request): JsonResponse
    {
        $request->validate([
            'token'       => 'required|string',
            'device_type' => 'required|in:android,ios',
            'device_name' => 'nullable|string',
        ]);

        FcmToken::updateOrCreate(
            ['token' => $request->token],
            [
                'user_id'     => $request->user()->id,
                'device_type' => $request->device_type,
                'device_name' => $request->device_name,
            ]
        );

        return response()->json(['message' => 'FCM token saved']);
    }
}
