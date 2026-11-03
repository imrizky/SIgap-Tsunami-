<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmergencyReport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PetugasDashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $total = EmergencyReport::count();

        $menunggu = EmergencyReport::where(
            'status',
            'menunggu'
        )->count();

        $diproses = EmergencyReport::where(
            'status',
            'diproses'
        )->count();

        $selesai = EmergencyReport::where(
            'status',
            'selesai'
        )->count();

        $laporanTerbaru = EmergencyReport::latest()
            ->limit(10)
            ->get();

        return response()->json([
            'message' => 'Dashboard petugas berhasil diambil.',
            'data' => [
                'ringkasan' => [
                    'total_laporan' => $total,
                    'menunggu' => $menunggu,
                    'diproses' => $diproses,
                    'selesai' => $selesai,
                ],
                'laporan_terbaru' => $laporanTerbaru,
            ],
        ]);
    }
}
