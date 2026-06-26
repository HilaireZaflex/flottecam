<?php

return [
    /*
    |--------------------------------------------------------------------------
    | CORS Configuration — FlotteCam PWA
    |--------------------------------------------------------------------------
    | Autorise la PWA Flutter Web (Railway) à appeler l'API Laravel (Railway)
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie', 'up'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        'https://adequate-warmth-production-a90c.up.railway.app',
        'http://localhost:*',
        'http://127.0.0.1:*',
    ],

    'allowed_origins_patterns' => [
        '/^https:\/\/.*\.up\.railway\.app$/',
        '/^http:\/\/localhost(:\d+)?$/',
        '/^http:\/\/127\.0\.0\.1(:\d+)?$/',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 86400,

    'supports_credentials' => false,
];
