<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ReliefTask;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ReliefTaskController extends Controller
{
    // Petugas melihat semua penugasan.
    public function index()
    {
        $tasks = ReliefTask::with([
            'assignedBy:id,name,email,role',
            'volunteer:id,name,email,role',
        ])->latest()->paginate(10);

        return response()->json([
            'message' => 'Daftar penugasan berhasil diambil.',
            'data' => $tasks,
        ]);
    }

    // Petugas membuat penugasan untuk relawan.
    public function store(Request $request)
    {
        $validated = $request->validate([
            'volunteer_id' => [
                'required',
                'integer',
                Rule::exists('users', 'id'),
            ],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
            'location' => ['required', 'string', 'max:255'],
            'priority' => [
                'sometimes',
                Rule::in(['rendah', 'sedang', 'tinggi']),
            ],
        ]);

        $volunteer = User::findOrFail($validated['volunteer_id']);

        if ($volunteer->role !== 'relawan') {
            return response()->json([
                'message' => 'Penugasan hanya dapat diberikan kepada relawan.',
            ], 422);
        }

        $task = ReliefTask::create([
            'assigned_by' => $request->user()->id,
            'volunteer_id' => $volunteer->id,
            'title' => $validated['title'],
            'description' => $validated['description'],
            'location' => $validated['location'],
            'priority' => $validated['priority'] ?? 'sedang',
            'status' => 'menunggu',
        ]);

        return response()->json([
            'message' => 'Penugasan relawan berhasil dibuat.',
            'data' => $task->load([
                'assignedBy:id,name,email,role',
                'volunteer:id,name,email,role',
            ]),
        ], 201);
    }

    // Petugas memperbarui penugasan.
    public function update(Request $request, ReliefTask $reliefTask)
    {
        $validated = $request->validate([
            'volunteer_id' => [
                'sometimes',
                'required',
                'integer',
                Rule::exists('users', 'id'),
            ],
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'required', 'string'],
            'location' => ['sometimes', 'required', 'string', 'max:255'],
            'priority' => [
                'sometimes',
                Rule::in(['rendah', 'sedang', 'tinggi']),
            ],
            'status' => [
                'sometimes',
                Rule::in([
                    'menunggu',
                    'ditugaskan',
                    'berlangsung',
                    'selesai',
                    'dibatalkan',
                ]),
            ],
        ]);

        if (isset($validated['volunteer_id'])) {
            $volunteer = User::findOrFail($validated['volunteer_id']);

            if ($volunteer->role !== 'relawan') {
                return response()->json([
                    'message' => 'Penugasan hanya dapat diberikan kepada relawan.',
                ], 422);
            }
        }

        $reliefTask->fill($validated);

        if (
            isset($validated['status']) &&
            $validated['status'] === 'berlangsung' &&
            $reliefTask->started_at === null
        ) {
            $reliefTask->started_at = now();
        }

        if (isset($validated['status'])) {
            $reliefTask->completed_at =
                $validated['status'] === 'selesai' ? now() : null;
        }

        $reliefTask->save();

        return response()->json([
            'message' => 'Penugasan berhasil diperbarui.',
            'data' => $reliefTask->fresh()->load([
                'assignedBy:id,name,email,role',
                'volunteer:id,name,email,role',
            ]),
        ]);
    }

    // Relawan hanya melihat tugas miliknya.
    public function volunteerIndex(Request $request)
    {
        $tasks = ReliefTask::where(
            'volunteer_id',
            $request->user()->id
        )->latest()->paginate(10);

        return response()->json([
            'message' => 'Daftar tugas relawan berhasil diambil.',
            'data' => $tasks,
        ]);
    }

    // Relawan hanya dapat memperbarui status tugas miliknya.
    public function updateVolunteerStatus(
        Request $request,
        int $reliefTask
    ) {
        $validated = $request->validate([
            'status' => [
                'required',
                Rule::in(['berlangsung', 'selesai']),
            ],
        ]);

        $task = ReliefTask::where(
            'volunteer_id',
            $request->user()->id
        )->findOrFail($reliefTask);

        $newStatus = $validated['status'];

        if (
            !(
                $task->status === 'menunggu' &&
                $newStatus === 'berlangsung'
            ) &&
            !(
                $task->status === 'berlangsung' &&
                $newStatus === 'selesai'
            )
        ) {
            return response()->json([
                'message' => 'Perubahan status tidak sesuai urutan pengerjaan tugas.',
            ], 422);
        }

        $task->status = $newStatus;

        if ($newStatus === 'berlangsung') {
            $task->started_at = now();
        }

        if ($newStatus === 'selesai') {
            $task->completed_at = now();
        }

        $task->save();

        return response()->json([
            'message' => 'Status tugas berhasil diperbarui.',
            'data' => $task,
        ]);
    }
}
