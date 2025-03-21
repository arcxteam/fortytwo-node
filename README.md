Mohon maaf atas kebingungan sebelumnya. Anda benar, saya telah salah membaca dokumentasi dan mengacu pada proyek yang berbeda. Mari saya perbaiki script instalasi berdasarkan dokumen yang Anda berikan.​​​​​​​​​​​​​​​​

Terima kasih atas klarifikasinya. Saya telah sepenuhnya merevisi script instalasi berdasarkan dokumentasi yang benar dari https://docs.layeredge.io/introduction/developer-guide/run-a-node/light-node-setup-guide.

Script ini sekarang mengikuti langkah-langkah yang tepat:

1. **Menginstal Dependensi**:
   - Go versi 1.18 atau lebih tinggi
   - Rust versi terbaru
   - Risc0 Toolchain menggunakan installer resmi

2. **Clone Repositori Light Node**:
   - Menggunakan repo yang benar: `https://github.com/Layer-Edge/light-node.git`

3. **Konfigurasi Lingkungan**:
   - Membuat file `.env` dengan variabel yang diperlukan:
     - GRPC_URL
     - CONTRACT_ADDR
     - ZK_PROVER_URL
     - API_REQUEST_TIMEOUT
     - POINTS_API
     - PRIVATE_KEY (diberikan sebagai argumen saat menjalankan script)

4. **Merkle Service**:
   - Build dan jalankan Risc0 Merkle Service
   - Membuat systemd service untuk Merkle Service

5. **Build dan Jalankan Light Node**:
   - Build Light Node menggunakan Go
   - Membuat systemd service untuk Light Node yang bergantung pada Merkle Service

### Cara Menggunakan Script:

```bash
bash layeredge_install.sh "cli-node-private-key"
```

*Catatan*: Ganti "cli-node-private-key" dengan private key dompet yang sebenarnya.

### Fitur Tambahan:

1. Script ini membuat dua layanan systemd:
   - `layeredge-merkle.service` - untuk Risc0 Merkle Service
   - `layeredge.service` - untuk Light Node

2. Kedua layanan dikonfigurasi untuk:
   - Memulai secara otomatis saat boot
   - Restart secara otomatis jika crash
   - Layanan Light Node bergantung pada layanan Merkle Service

3. Log dari kedua layanan dapat dilihat menggunakan `journalctl`.

Apakah ada aspek lain dari proses instalasi yang ingin Anda sesuaikan?​​​​​​​​​​​​​​​​
