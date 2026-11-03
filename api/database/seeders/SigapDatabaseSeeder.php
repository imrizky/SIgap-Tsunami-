<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\EvacuationPoint;
use App\Models\Alert;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class SigapDatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Fixed-credential demo users and sample locations are local/test data only.
        if (! app()->environment(['local', 'testing'])) {
            return;
        }
        // 1. Akun Standar 4 Role untuk Pengujian dan Penggunaan
        $users = [
            [
                'name' => 'Warga Sigap',
                'email' => 'warga@sigap.test',
                'role' => 'warga',
                'password' => Hash::make('password123'),
            ],
            [
                'name' => 'Relawan Sigap',
                'email' => 'relawan@sigap.test',
                'role' => 'relawan',
                'password' => Hash::make('password123'),
            ],
            [
                'name' => 'Petugas BPBD Sigap',
                'email' => 'petugas@sigap.test',
                'role' => 'petugas',
                'password' => Hash::make('password123'),
            ],
            [
                'name' => 'Admin Sigap',
                'email' => 'admin@sigap.test',
                'role' => 'admin',
                'password' => Hash::make('password123'),
            ],
        ];

        foreach ($users as $userData) {
            User::updateOrCreate(
                ['email' => $userData['email']],
                $userData
            );
        }

        // 2. Titik Evakuasi Aktif Wilayah Kampus UNP & Sekitar Padang
        $points = [
            [
                'name' => 'Rectorate and Research Center UNP',
                'description' => 'Gedung utama pusat riset dan rektorat bertingkat tinggi dengan konstruksi tahan gempa, berfungsi sebagai Titik Evakuasi Sementara (TES).',
                'address' => 'Jl. Prof. Dr. Hamka, Air Tawar Bar., Padang',
                'latitude' => -0.8973000,
                'longitude' => 100.3508000,
                'type' => 'tempat_evakuasi',
                'capacity' => 1000,
                'status' => 'aktif',
            ],
            [
                'name' => 'Gedung MKU UNP',
                'description' => 'Gedung perkuliahan lantai 4, aman untuk evakuasi vertikal darurat.',
                'address' => 'Kampus UNP Air Tawar, Padang',
                'latitude' => -0.8965000,
                'longitude' => 100.3512000,
                'type' => 'tempat_evakuasi',
                'capacity' => 500,
                'status' => 'aktif',
            ],
            [
                'name' => 'Fakultas Ekonomi UNP',
                'description' => 'Shelter evakuasi mandiri dengan akses tangga darurat lebar di sisi utara dan selatan.',
                'address' => 'Kampus UNP Air Tawar, Padang',
                'latitude' => -0.8980000,
                'longitude' => 100.3520000,
                'type' => 'tempat_evakuasi',
                'capacity' => 600,
                'status' => 'aktif',
            ],
            [
                'name' => 'Gedung FT UNP',
                'description' => 'Gedung Fakultas Teknik lantai atas dengan fasilitas logistik darurat.',
                'address' => 'Kampus UNP Air Tawar, Padang',
                'latitude' => -0.8990000,
                'longitude' => 100.3515000,
                'type' => 'tempat_evakuasi',
                'capacity' => 700,
                'status' => 'aktif',
            ],
            [
                'name' => 'Titik Kumpul Lapangan Rektorat UNP',
                'description' => 'Area terbuka luas bebas runtuhan gedung, titik konsolidasi awal warga dan mahasiswa sebelum evakuasi vertikal.',
                'address' => 'Air Tawar, Padang',
                'latitude' => -0.8970000,
                'longitude' => 100.3505000,
                'type' => 'titik_kumpul',
                'capacity' => 1500,
                'status' => 'aktif',
            ],
            [
                'name' => 'Posko Bantuan Pantai Gajah',
                'description' => 'Posko pelayanan darurat kesehatan dan logistik.',
                'address' => 'Jl. Samudera No. 12, Pantai Gajah, Padang',
                'latitude' => -0.8920000,
                'longitude' => 100.3450000,
                'type' => 'posko',
                'capacity' => 400,
                'status' => 'aktif',
            ],
        ];

        foreach ($points as $p) {
            EvacuationPoint::updateOrCreate(
                ['name' => $p['name']],
                $p
            );
        }

        // 3. Peringatan Simulasi / Demonstrasi (Diberi label jelas sesuai BRD)
        $petugas = User::where('role', 'petugas')->first();
        if ($petugas) {
            Alert::updateOrCreate(
                ['title' => 'Simulasi: Peringatan Kesiapsiagaan Tsunami Padang'],
                [
                    'user_id' => $petugas->id,
                    'title' => 'Simulasi: Peringatan Kesiapsiagaan Tsunami Padang',
                    'message' => 'Simulasi kesiapsiagaan tsunami untuk wilayah pesisir Pantai Gajah dan Air Tawar. Harap kenali jalur evakuasi menuju tempat tinggi. CATATAN: Ini adalah data simulasi aplikasi Sigap Tsunami, bukan peringatan bencana nyata.',
                    'type' => 'tsunami',
                    'severity' => 'waspada',
                    'affected_area' => 'Pantai Gajah, Air Tawar, Padang',
                    'source' => 'Simulasi Sistem Sigap Tsunami (Data Uji)',
                    'status' => 'aktif',
                    'published_at' => now(),
                    'ends_at' => now()->addDays(7),
                ]
            );
        }
    }
}
