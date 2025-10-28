// Cegah update Racking jika rak tidak aktif
Parse.Cloud.beforeSave("Racking", async (request) => {
  const rak = request.object;

  // Jika data lama ada (update)
  if (request.original) {
    const wasActive = request.original.get("active");
    const oldOccupied = request.original.get("occupied");
    const newOccupied = request.object.get("occupied");
    if (!wasActive) {
      throw new Parse.Error(403, "Rak ini tidak bisa dipakai");
    }
    if (oldOccupied === false && newOccupied === false) {
      throw new Parse.Error(403, "Rak ini belum terpakai");
    }
    if (oldOccupied === true && newOccupied === true) {
      throw new Parse.Error(403, "Rak ini sudah terpakai");
    }
  }
});

// History hanya bisa dibuat lewat Cloud Code
Parse.Cloud.beforeSave("History", async (request) => {
  if (!request.master) {
    throw new Parse.Error(403, "History hanya bisa dibuat lewat Cloud Code");
  }
});

// Catat history jika status occupied berubah
Parse.Cloud.afterSave("Racking", async (request) => {
  try {
    // Pastikan data lama ada (berarti update, bukan create baru)
    if (request.original) {
      const oldOccupied = request.original.get("occupied");
      const newOccupied = request.object.get("occupied");

      // Cek hanya jika terjadi perubahan status occupied
      if (newOccupied !== oldOccupied) {
        const History = Parse.Object.extend("History");
        const history = new History();

        history.set("action", newOccupied ? "IN" : "OUT");
        history.set("row", request.object.get("row"));
        history.set("col", request.object.get("col"));
        history.set("timestamp", new Date());

        await history.save(null, { useMasterKey: true });
        console.log(
          `History dicatat: row ${request.object.get("row")}, col ${request.object.get("col")}`
        );
      }
    }
  } catch (err) {
    console.error("Error mencatat history:", err);
    throw new Parse.Error(500, `Gagal mencatat history: ${err.message}`);
  }
});


// Bulk update racking occupied status (optimized untuk import besar)
// Format input: [{ row: number, col: number, occupied: boolean }, ...]
Parse.Cloud.define("bulkUpdateRackingOccupied", async (request) => {
  const { updates } = request.params;

  if (!Array.isArray(updates) || updates.length === 0) {
    throw new Parse.Error(400, "Updates harus array dan tidak boleh kosong");
  }

  const results = {
    success: [],
    failed: [],
  };

  try {
    // Kumpulkan semua rak yang perlu diupdate
    const rackingObjects = [];

    for (const update of updates) {
      try {
        const { row, col, occupied } = update;

        // Validasi input
        if (typeof row !== "number" || typeof col !== "number") {
          results.failed.push({
            row,
            col,
            error: "Row dan col harus berupa angka",
          });
          continue;
        }

        if (typeof occupied !== "boolean") {
          results.failed.push({
            row,
            col,
            error: "Occupied harus berupa boolean",
          });
          continue;
        }

        // Query untuk cari rak
        const query = new Parse.Query("Racking");
        query.equalTo("row", row);
        query.equalTo("col", col);
        const rak = await query.first({ useMasterKey: true });

        if (!rak) {
          results.failed.push({
            row,
            col,
            error: "Rak tidak ditemukan di database",
          });
          continue;
        }

        // Cek rak harus active
        if (!rak.get("active")) {
          results.failed.push({
            row,
            col,
            error: "Rak ini tidak aktif",
          });
          continue;
        }

        // Hanya update jika ada perubahan status occupied
        const currentOccupied = rak.get("occupied");
        if (currentOccupied !== occupied) {
          rak.set("occupied", occupied);
          rackingObjects.push(rak);
          results.success.push({ row, col, occupied });
        } else {
          results.success.push({ row, col, occupied, message: "Tidak ada perubahan" });
        }
      } catch (err) {
        results.failed.push({
          row: update.row,
          col: update.col,
          error: err.message,
        });
      }
    }

    // Batch save semua racking yang berubah
    if (rackingObjects.length > 0) {
      await Parse.Object.saveAll(rackingObjects, { useMasterKey: true });
      console.log(`Bulk update berhasil: ${rackingObjects.length} rak diupdate`);
    }

    return {
      totalProcessed: updates.length,
      successCount: results.success.length,
      failedCount: results.failed.length,
      details: results,
    };
  } catch (err) {
    console.error("Error dalam bulk update:", err);
    throw new Parse.Error(500, `Gagal bulk update: ${err.message}`);
  }
});

// Get history untuk hari ini saja (server-side filtering dengan UTC)
// Tidak perlu pass tanggal, server otomatis filter based on current UTC time
Parse.Cloud.define("getTodayHistory", async (request) => {
  try {
    // Calculate UTC range for today in WIB (UTC+7)
    const now = new Date(); // Server time (UTC)

    // Get today's date in WIB (add 7 hours)
    const wibDate = new Date(now.getTime() + 7 * 60 * 60 * 1000);
    const todayStartWib = new Date(wibDate.getUTCFullYear(), wibDate.getUTCMonth(), wibDate.getUTCDate(), 0, 0, 0, 0);
    const todayEndWib = new Date(todayStartWib.getTime() + 24 * 60 * 60 * 1000);

    // Convert back to UTC for database query
    const todayStartUtc = new Date(todayStartWib.getTime() - 7 * 60 * 60 * 1000);
    const todayEndUtc = new Date(todayEndWib.getTime() - 7 * 60 * 60 * 1000);

    console.log(`getTodayHistory: WIB range ${todayStartWib} - ${todayEndWib}`);
    console.log(`getTodayHistory: UTC range ${todayStartUtc} - ${todayEndUtc}`);

    // Query History with UTC timestamp range
    const query = new Parse.Query("History");
    query.greaterThanOrEqualTo("timestamp", todayStartUtc);
    query.lessThan("timestamp", todayEndUtc);
    query.descending("timestamp");

    const results = await query.find({ useMasterKey: true });

    // Convert to plain objects
    const historyList = results.map((obj) => ({
      objectId: obj.id,
      action: obj.get("action"),
      row: obj.get("row"),
      col: obj.get("col"),
      timestamp: obj.get("timestamp"),
    }));

    console.log(`getTodayHistory: Returned ${historyList.length} records`);

    return {
      success: true,
      count: historyList.length,
      data: historyList,
    };
  } catch (err) {
    console.error("Error getting today history:", err);
    throw new Parse.Error(500, `Gagal get today history: ${err.message}`);
  }
});
