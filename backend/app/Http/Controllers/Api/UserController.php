<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $users = User::where('company_id', $request->user()->company_id)
            ->when($request->search, fn($q) => $q->where('name', 'like', "%{$request->search}%")
                ->orWhere('email', 'like', "%{$request->search}%"))
            ->latest()
            ->paginate(20);

        return response()->json($users);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users',
            'password' => 'required|string|min:8',
            'role'     => 'required|in:admin,manager,dispatcher,driver',
            'phone'    => 'nullable|string',
        ]);

        $user = User::create([
            'company_id' => $request->user()->company_id,
            'name'       => $validated['name'],
            'email'      => $validated['email'],
            'password'   => Hash::make($validated['password']),
            'role'       => $validated['role'],
            'phone'      => $validated['phone'] ?? null,
        ]);

        return response()->json(['message' => 'User created', 'user' => $user], 201);
    }

    public function show(Request $request, User $user): JsonResponse
    {
        $this->authorizeCompany($request, $user->company_id);
        return response()->json(['user' => $user]);
    }

    public function update(Request $request, User $user): JsonResponse
    {
        $this->authorizeCompany($request, $user->company_id);

        $validated = $request->validate([
            'name'      => 'sometimes|string',
            'email'     => 'sometimes|email|unique:users,email,' . $user->id,
            'role'      => 'sometimes|in:admin,manager,dispatcher,driver',
            'is_active' => 'sometimes|boolean',
            'password'  => 'sometimes|string|min:8',
        ]);

        if (isset($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        }

        $user->update($validated);
        return response()->json(['message' => 'User updated', 'user' => $user]);
    }

    public function destroy(Request $request, User $user): JsonResponse
    {
        $this->authorizeCompany($request, $user->company_id);
        if ($user->id === $request->user()->id) {
            return response()->json(['message' => 'Cannot delete yourself'], 422);
        }
        $user->delete();
        return response()->json(['message' => 'User deleted']);
    }

    public function profile(Request $request): JsonResponse
    {
        return response()->json(['user' => $request->user()->load('company', 'driver')]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user      = $request->user();
        $validated = $request->validate([
            'name'     => 'sometimes|string',
            'email'    => 'sometimes|email|unique:users,email,' . $user->id,
            'phone'    => 'sometimes|string',
            'password' => 'sometimes|string|min:8|confirmed',
        ]);

        if (isset($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        }

        $user->update($validated);
        return response()->json(['message' => 'Profile updated', 'user' => $user]);
    }

    public function updatePhoto(Request $request): JsonResponse
    {
        $request->validate(['photo' => 'required|image|max:2048']);
        $user = $request->user();
        if ($user->avatar && Storage::exists($user->avatar)) {
            Storage::delete($user->avatar);
        }
        $path = $request->file('photo')->store('avatars', 'public');
        $user->update(['avatar' => Storage::url($path)]);
        return response()->json(['message' => 'Photo updated', 'avatar' => $user->avatar]);
    }

    private function authorizeCompany(Request $request, int $companyId): void
    {
        if ($request->user()->company_id !== $companyId) {
            abort(403, 'Unauthorized');
        }
    }
}
