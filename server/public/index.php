<?php
declare(strict_types=1);

use PetTrack\Auth;
use PetTrack\Database;
use PetTrack\Http;
use PetTrack\Service;

require dirname(__DIR__) . '/src/Database.php';
require dirname(__DIR__) . '/src/Auth.php';
require dirname(__DIR__) . '/src/Service.php';
require dirname(__DIR__) . '/src/Http.php';

Http::run();
