<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Company;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Laravel\Socialite\Facades\Socialite;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'company_name' => 'required|string|max:255',
            'name'         => 'required|string|max:255',
            'email'        => 'required|email|unique:users',
            'password'     => 'required|string|min:8|confirmed',
            'phone'        => 'nullable|string|max:20',
        ]);

        // Create company
        $company = Company::create([
            'name'  => $validated['company_name'],
            'email' => $validated['email'],
            'phone' => $validated['phone'] ?? null,
        ]);

        // Create admin user
        $user = User::create([
            'company_id' => $company->id,
            'name'       => $validated['name'],
            'email'      => $validated['email'],
            'password'   => Hash::make($validated['password']),
            'role'       => 'admin',
            'email_verified_at' => now(),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Company and account created successfully',
            'user'    => $user->load('company'),
            'token'   => $token,
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        $user = User::with('company')->where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        if (!$user->is_active) {
            return response()->json(['message' => 'Your account has been deactivated.'], 403);
        }

        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;
        $user->update(['last_login_at' => now()]);

        return response()->json([
            'message' => 'Login successful',
            'user'    => $user,
            'token'   => $token,
        ]);
    }

    public function loginWithGoogle(Request $request): JsonResponse
    {
        $request->validate(['token' => 'required|string']);
        try {
            $socialUser = Socialite::driver('google')->stateless()->userFromToken($request->token);
            return $this->handleSocialLogin($socialUser, 'google');
        } catch (\Exception $e) {
            return response()->json(['message' => 'Invalid Google token.'], 401);
        }
    }

    public function loginWithFacebook(Request $request): JsonResponse
    {
        $request->validate(['token' => 'required|string']);
        try {
            $socialUser = Socialite::driver('facebook')->stateless()->userFromToken($request->token);
            return $this->handleSocialLogin($socialUser, 'facebook');
        } catch (\Exception $e) {
            return response()->json(['message' => 'Invalid Facebook token.'], 401);
        }
    }

    private function handleSocialLogin($socialUser, string $provider): JsonResponse
    {
        $user = User::where('email', $socialUser->getEmail())->first();

        if (!$user) {
            // Create company + user
            $company = Company::create([
                'name'  => $socialUser->getName() . "'s Company",
                'email' => $socialUser->getEmail(),
            ]);
            $user = User::create([
                'company_id'       => $company->id,
                'name'             => $socialUser->getName(),
                'email'            => $socialUser->getEmail(),
                'password'         => Hash::make(Str::random(24)),
                "{$provider}_id"   => $socialUser->getId(),
                'avatar'           => $socialUser->getAvatar(),
                'email_verified_at'=> now(),
                'role'             => 'admin',
            ]);
        } else {
            $user->update(["{$provider}_id" => $socialUser->getId()]);
        }

        if (!$user->is_active) {
            return response()->json(['message' => 'Account deactivated.'], 403);
        }

        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;
        $user->update(['last_login_at' => now()]);

        return response()->json([
            'message' => 'Login successful',
            'user'    => $user->load('company'),
            'token'   => $token,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out successfully']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $request->user()->load('company', 'driver')]);
    }
}
