<?php

namespace App\Models;

use Illuminate\Notifications\DatabaseNotification;

/**
 * Modèle Notification — alias de DatabaseNotification de Laravel.
 * Nécessaire car Notifiable::notifications() résout morphTo vers App\Models\Notification.
 */
class Notification extends DatabaseNotification
{
    //
}
