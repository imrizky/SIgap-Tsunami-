<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EvacuationPoint;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class EvacuationPointController extends Controller
{
    // Menampilkan daftar titik evakuasi aktif
    public function index()
    {
        $points = EvacuationPoint::where('status', 'aktif')
            ->latest()
            ->paginate(10);

        return response()->json($points);
    }

    // Menampilkan detail titik evakuasi
    public function show(EvacuationPoint $evacuationPoint)
    {
        if ($evacuationPoint->status !== 'aktif') {
            return response()->json([
                'message' => 'Titik evakuasi tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'data' => $evacuationPoint,
        ]);
    }

    // Menambahkan titik evakuasi
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:2000'],
            'address' => ['required', 'string', 'max:255'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'type' => [
                'required',
                Rule::in([
                    'tempat_evakuasi',
                    'titik_kumpul',
                    'posko',
                ]),
            ],
            'capacity' => ['nullable', 'integer', 'min:0'],
        ]);

        $point = EvacuationPoint::create($validated);

        return response()->json([
            'message' => 'Titik evakuasi berhasil ditambahkan.',
            'data' => $point,
        ], 201);
    }

    // Memperbarui titik evakuasi
    public function update(
        Request $request,
        EvacuationPoint $evacuationPoint
    ) {
        $validated = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'address' => ['sometimes', 'required', 'string', 'max:255'],
            'latitude' => ['sometimes', 'required', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'required', 'numeric', 'between:-180,180'],
            'type' => [
                'sometimes',
                'required',
                Rule::in([
                    'tempat_evakuasi',
                    'titik_kumpul',
                    'posko',
                ]),
            ],
            'capacity' => ['sometimes', 'nullable', 'integer', 'min:0'],
            'status' => [
                'sometimes',
                'required',
                Rule::in(['aktif', 'nonaktif']),
            ],
        ]);

        $evacuationPoint->update($validated);

        return response()->json([
            'message' => 'Titik evakuasi berhasil diperbarui.',
            'data' => $evacuationPoint,
        ]);
    }

    // Menonaktifkan titik evakuasi tanpa menghapus datanya
    public function destroy(EvacuationPoint $evacuationPoint)
    {
        $evacuationPoint->update([
            'status' => 'nonaktif',
        ]);

        return response()->json([
            'message' => 'Titik evakuasi berhasil dinonaktifkan.',
        ]);
    }
}
