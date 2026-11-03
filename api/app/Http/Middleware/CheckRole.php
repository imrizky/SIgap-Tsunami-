<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'message' => 'Silakan login terlebih dahulu.',
            ], 401);
        }

        if (!in_array($user->role, $roles, true)) {
            return response()->json([
                'message' => 'Kamu tidak memiliki izin untuk mengakses fitur ini.',
            ], 403);
        }

        return $next($request);
    }
}
