<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Alert;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AlertController extends Controller
{
    // Warga dan petugas dapat melihat informasi peringatan.
    public function index()
    {
        return Alert::where(function ($query) {
                $query->where('status', 'aktif')
                    ->orWhere('status', 'berakhir');
            })
            ->where(function ($query) {
                $query->whereNull('published_at')
                    ->orWhere('published_at', '<=', now());
            })
            ->orderByDesc('published_at')
            ->orderByDesc('id')
            ->paginate(10);
    }

    public function show(Alert $alert)
    {
        abort_unless(
            in_array($alert->status, ['aktif', 'berakhir'])
            && ($alert->published_at === null || $alert->published_at->lte(now())),
            404
        );

        return response()->json($alert);
    }

    // Hanya petugas yang diizinkan oleh middleware dapat membuat peringatan.
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'message' => ['required', 'string'],
            'type' => ['required', Rule::in(['tsunami', 'gempa', 'cuaca', 'informasi'])],
            'severity' => ['required', Rule::in(['waspada', 'siaga', 'darurat'])],
            'affected_area' => ['required', 'string', 'max:255'],
            'source' => ['required', 'string', 'max:255'],
            'status' => ['sometimes', Rule::in(['aktif', 'berakhir'])],
            'published_at' => ['nullable', 'date'],
            'ends_at' => ['nullable', 'date', 'after:published_at'],
        ]);

        $validated['user_id'] = $request->user()->id;
        $validated['published_at'] ??= now();

        $alert = Alert::create($validated);

        return response()->json([
            'message' => 'Informasi peringatan berhasil dibuat.',
            'data' => $alert,
        ], 201);
    }

    public function update(Request $request, Alert $alert)
    {
        $validated = $request->validate([
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'message' => ['sometimes', 'required', 'string'],
            'type' => ['sometimes', Rule::in(['tsunami', 'gempa', 'cuaca', 'informasi'])],
            'severity' => ['sometimes', Rule::in(['waspada', 'siaga', 'darurat'])],
            'affected_area' => ['sometimes', 'required', 'string', 'max:255'],
            'source' => ['sometimes', 'required', 'string', 'max:255'],
            'status' => ['sometimes', Rule::in(['aktif', 'berakhir'])],
            'published_at' => ['sometimes', 'nullable', 'date'],
            'ends_at' => ['sometimes', 'nullable', 'date', 'after:published_at'],
        ]);

        $alert->update($validated);

        return response()->json([
            'message' => 'Informasi peringatan berhasil diperbarui.',
            'data' => $alert->fresh(),
        ]);
    }
}
