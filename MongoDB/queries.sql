//1.
db.station_schedules.aggregate([
  {
    $group: {
      _id: "$sucursal_id",
      dias_apertura: { $addToSet: "$day_of_week" }
    }
  }
]);
//2.
db.user_feedback.aggregate([
  {
    $group: {
      _id: 0,
      promedio_rating: { $avg: "$rating" },
    }
  }
]);
//3.
db.system_alerts.aggregate([
  {
    $match: {
      level: { $in: ["critical", "high"] }
    }
  }
])
//4.
db.notifications.aggregate([
  {
    $unwind: "$notifications"
  },
  {
    $match: {
      "notifications.read": false
    }
  },
  {
    $project: {
        mensajes: "$notifications.message"
    }
  }
])
//5.
db.users_requests.aggregate([
  {
    $unwind: "$requests"
  },
  {
      $group: {
        _id: "$requests.type",
        total: { $sum: 1 }
      }
  }
]);
//6.
db.users_requests.aggregate([
  {
    $unwind: "$requests"
  },
  {
      $group: {
        _id: "$requests.status",
        total: { $sum: 1 }
      }
  }
]);
//7.
db.payment_type.aggregate([
  {
    $group: {
      _id: "$payment_info.method",
      monto_total: { $sum: "$payment_info.amount" }
    }
  },
  {
    $sort: { monto_total: 1 }
  }
]);
//8.
db.users_requests.aggregate([
  {
    $project: {
        _id: 0,
      user_id: 1,
      total_solicitudes: { $size: "$requests" }
    }
  },
  {
    $sort: { total_solicitudes: -1 }
  }
]);
//9.
db.system_alerts.aggregate([
  {
    $group: {
      _id: "$level",
      total: { $sum: 1 }
    }
  }
])
//10.
db.station_schedules.aggregate([
  {
    $group: {
      _id: "$opening_time",
      total_estaciones: { $sum: 1 }
    }
  }
]);
//11.
db.payment_type.aggregate([
  {
    $group: {
      _id: "$payment_info.status",
      total: { $sum: 1 },
      monto_total: { $sum: "$payment_info.amount" }
    }
  }
]);
//12.
db.user_feedback.aggregate([
  {
    $match: {
        rating: {$lte: 2}
    }
  },
  {
  $project: {
    rating: "$rating",
    comentario: "$comment"
    }
  }
]);
//13.
db.notifications.aggregate([
  {
    $unwind: "$notifications"
  },
  {
    $match: {
      "notifications.metadata.status": "confirmed"
    }
  },
  {
    $project: {
      user_id: 1,
      notification_id: "$notifications._id",
      message: "$notifications.message",
      date: "$notifications.date",
      status: "$notifications.metadata.status"
    }
  }
])