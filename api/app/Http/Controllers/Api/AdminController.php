<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\EmergencyReport;
use App\Models\ReliefTask;
use App\Models\EvacuationPoint;
use App\Models\Alert;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminController extends Controller
{
    /**
     * Menampilkan daftar seluruh pengguna untuk administrator.
     */
    public function users(Request $request)
    {
        $query = User::query()->select('id', 'name', 'email', 'role', 'created_at');

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        return response()->json([
            'message' => 'Daftar pengguna berhasil diambil.',
            'data' => $query->latest()->paginate(15),
        ]);
    }

    /**
     * Mengubah peran (role) pengguna oleh administrator.
     */
    public function updateRole(Request $request, User $user)
    {
        $validated = $request->validate([
            'role' => [
                'required',
                Rule::in(['warga', 'relawan', 'petugas', 'admin']),
            ],
        ]);

        $user->update(['role' => $validated['role']]);

        return response()->json([
            'message' => "Peran pengguna {$user->name} berhasil diubah menjadi {$user->role}.",
            'data' => $user->only('id', 'name', 'email', 'role', 'updated_at'),
        ]);
    }

    /**
     * Menampilkan ringkasan statistik sistem untuk dashboard administrator.
     */
    public function stats()
    {
        return response()->json([
            'message' => 'Statistik sistem berhasil diambil.',
            'data' => [
                'total_users' => User::count(),
                'users_by_role' => [
                    'warga' => User::where('role', 'warga')->count(),
                    'relawan' => User::where('role', 'relawan')->count(),
                    'petugas' => User::where('role', 'petugas')->count(),
                    'admin' => User::where('role', 'admin')->count(),
                ],
                'total_reports' => EmergencyReport::count(),
                'reports_by_status' => [
                    'menunggu' => EmergencyReport::where('status', 'menunggu')->count(),
                    'diproses' => EmergencyReport::where('status', 'diproses')->count(),
                    'selesai' => EmergencyReport::where('status', 'selesai')->count(),
                ],
                'total_evacuation_points' => EvacuationPoint::count(),
                'total_relief_tasks' => ReliefTask::count(),
                'total_alerts' => Alert::count(),
            ],
        ]);
    }
}
