<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Operation;
use App\Models\Transport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OperationController extends Controller
{
    public function index(Request $request, Transport $transport): JsonResponse
    {
        $operations = $transport->operations()
            ->with('user')
            ->latest()
            ->get();

        return response()->json(['operations' => $operations]);
    }

    public function store(Request $request, Transport $transport): JsonResponse
    {
        $validated = $request->validate([
            'type'        => 'required|in:departure,arrival,stop,fuel,incident,delivery,pickup,note',
            'description' => 'required|string',
            'location'    => 'nullable|string',
            'lat'         => 'nullable|numeric',
            'lng'         => 'nullable|numeric',
            'metadata'    => 'nullable|array',
        ]);

        $operation = Operation::create([
            'transport_id' => $transport->id,
            'user_id'      => $request->user()->id,
            ...$validated,
        ]);

        return response()->json([
            'message'   => 'Operation logged successfully',
            'operation' => $operation->load('user'),
        ], 201);
    }
}
