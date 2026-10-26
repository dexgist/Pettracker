<?php
declare(strict_types=1);
namespace PetTrack;
use PDO;
use RuntimeException;
final class Database {
    private static ?PDO $connection = null;
    public static function connection(): PDO {
        if (self::$connection) return self::$connection;
        self::loadLocalEnv();
        date_default_timezone_set(getenv('APP_TIMEZONE') ?: 'Asia/Manila');
        $host = getenv('DB_HOST') ?: '127.0.0.1';
        $port = getenv('DB_PORT') ?: '3306';
        $name = getenv('DB_NAME') ?: 'pettrack';
        $user = getenv('DB_USER');
        $pass = getenv('DB_PASSWORD');
        if ($user === false || $pass === false) throw new RuntimeException('Database credentials are not configured.');
        self::$connection = new PDO("mysql:host={$host};port={$port};dbname={$name};charset=utf8mb4", $user, $pass, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
        $offset = getenv('DB_TIMEZONE_OFFSET') ?: '+08:00';
        if (!preg_match('/^[+-](?:0[0-9]|1[0-4]):[0-5][0-9]$/', $offset)) throw new RuntimeException('Database timezone offset is invalid.');
        self::$connection->exec("SET time_zone = '{$offset}'");
        return self::$connection;
    }
    private static function loadLocalEnv(): void {
        $file = dirname(__DIR__, 2) . '/.env';
        if (!is_file($file) || !is_readable($file)) return;
        foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) continue;
            [$key, $value] = explode('=', $line, 2);
            $key = trim($key); $value = trim(trim($value), "\\\"'");
            if (!preg_match('/^[A-Z][A-Z0-9_]*$/', $key) || getenv($key) !== false) continue;
            putenv($key . '=' . $value);
        }
    }
    public static function env(string $key, ?string $fallback = null): ?string {
        $value = getenv($key);
        return ($value === false || $value === '') ? $fallback : $value;
    }
}
