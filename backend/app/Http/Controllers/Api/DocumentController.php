<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Document;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class DocumentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $documents = Document::where('company_id', $request->user()->company_id)
            ->when($request->type, fn($q) => $q->where('type', $request->type))
            ->when($request->truck_id, fn($q) => $q
                ->where('documentable_type', 'App\\Models\\Truck')
                ->where('documentable_id', $request->truck_id))
            ->when($request->driver_id, fn($q) => $q
                ->where('documentable_type', 'App\\Models\\Driver')
                ->where('documentable_id', $request->driver_id))
            ->latest()
            ->paginate(20);

        return response()->json($documents);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'type'                  => 'required|string',
            'name'                  => 'required|string',
            'file'                  => 'required|file|max:10240',
            'documentable_type'     => 'required|in:truck,driver',
            'documentable_id'       => 'required|integer',
            'expiry_date'           => 'nullable|date',
            'notes'                 => 'nullable|string',
        ]);

        $path = $request->file('file')->store('documents', 'public');

        $document = Document::create([
            'company_id'         => $request->user()->company_id,
            'type'               => $request->type,
            'name'               => $request->name,
            'file_path'          => Storage::url($path),
            'documentable_type'  => 'App\\Models\\' . ucfirst($request->documentable_type),
            'documentable_id'    => $request->documentable_id,
            'expiry_date'        => $request->expiry_date,
            'notes'              => $request->notes,
        ]);

        return response()->json([
            'message'  => 'Document uploaded successfully',
            'document' => $document,
        ], 201);
    }

    public function destroy(Request $request, Document $document): JsonResponse
    {
        if ($document->company_id !== $request->user()->company_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $document->delete();
        return response()->json(['message' => 'Document deleted']);
    }
}
