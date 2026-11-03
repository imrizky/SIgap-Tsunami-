<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmergencyReport;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class EmergencyReportController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'incident_type' => [
                'required',
                Rule::in([
                    'tsunami',
                    'gempa',
                    'banjir',
                    'kebakaran',
                    'lainnya',
                ]),
            ],
            'description' => ['nullable', 'string', 'max:2000'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'address' => ['nullable', 'string', 'max:255'],
        ]);

        $report = EmergencyReport::create([
            'user_id' => $request->user()->id,
            'report_code' => 'SOS-' . strtoupper(Str::random(10)),
            ...$validated,
        ]);

        return response()->json([
            'message' => 'Laporan darurat berhasil dikirim.',
            'data' => $report,
        ], 201);
    }

    public function index(Request $request)
    {
        $user = $request->user();

        $reports = $user->role === 'petugas'
            ? EmergencyReport::with('user:id,name,email')
                ->latest()
                ->paginate(10)
            : EmergencyReport::where('user_id', $user->id)
                ->latest()
                ->paginate(10);

        return response()->json($reports);
    }

    public function show(Request $request, EmergencyReport $emergencyReport)
    {
        $user = $request->user();

        if (
            $user->role !== 'petugas' &&
            $emergencyReport->user_id !== $user->id
        ) {
            return response()->json([
                'message' => 'Kamu tidak memiliki izin melihat laporan ini.',
            ], 403);
        }

        return response()->json([
            'data' => $emergencyReport->load('user:id,name,email'),
        ]);
    }
    
    public function updateStatus(Request $request, EmergencyReport $emergencyReport)
    {
        $validated = $request->validate([
            'status' => [
                'required',
                'in:menunggu,diproses,selesai',
            ],
        ]);

        $emergencyReport->update([
            'status' => $validated['status'],
        ]);

        return response()->json([
            'message' => 'Status laporan berhasil diperbarui.',
            'data' => $emergencyReport,
        ]);
    }

public function dashboard()
{
    $total = \App\Models\EmergencyReport::count();

    $menunggu = \App\Models\EmergencyReport::where(
        'status',
        'menunggu'
    )->count();

    $diproses = \App\Models\EmergencyReport::where(
        'status',
        'diproses'
    )->count();

    $selesai = \App\Models\EmergencyReport::where(
        'status',
        'selesai'
    )->count();

    $laporanTerbaru = \App\Models\EmergencyReport::with(
        'user:id,name,email'
    )->latest()->take(5)->get();

    return response()->json([
        'message' => 'Data dashboard petugas berhasil diambil.',
        'data' => [
            'total_laporan' => $total,
            'menunggu' => $menunggu,
            'diproses' => $diproses,
            'selesai' => $selesai,
            'laporan_terbaru' => $laporanTerbaru,
        ],
    ]);
}

    }