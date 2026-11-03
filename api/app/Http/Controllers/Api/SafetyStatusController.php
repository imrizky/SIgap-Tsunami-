<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SafetyStatus;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class SafetyStatusController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'status' => [
                'required',
                Rule::in([
                    'aman',
                    'butuh_bantuan',
                    'dalam_bahaya',
                ]),
            ],
            'description' => ['nullable', 'string', 'max:2000'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
        ]);

        $safetyStatus = SafetyStatus::create([
            'user_id' => $request->user()->id,
            ...$validated,
        ]);

        return response()->json([
            'message' => 'Status keselamatan berhasil dikirim.',
            'data' => $safetyStatus,
        ], 201);
    }

    public function index(Request $request)
    {
        $user = $request->user();

        $statuses = $user->role === 'petugas'
            ? SafetyStatus::with('user:id,name,email')
                ->latest()
                ->paginate(10)
            : SafetyStatus::where('user_id', $user->id)
                ->latest()
                ->paginate(10);

        return response()->json($statuses);
    }

    public function show(Request $request, SafetyStatus $safetyStatus)
    {
        $user = $request->user();

        if (
            $user->role !== 'petugas' &&
            $safetyStatus->user_id !== $user->id
        ) {
            return response()->json([
                'message' => 'Kamu tidak memiliki izin melihat status ini.',
            ], 403);
        }

        return response()->json([
            'data' => $safetyStatus->load('user:id,name,email'),
        ]);
    }
}
