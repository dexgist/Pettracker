<?php
declare(strict_types=1);
namespace PetTrack;
use Throwable;
final class Http {
    public static function respond(array $data,int $status=200): never { http_response_code($status);header('Content-Type: application/json; charset=utf-8');header('Cache-Control: no-store');echo json_encode($data,JSON_UNESCAPED_SLASHES|JSON_INVALID_UTF8_SUBSTITUTE);exit; }
    public static function fail(int $status,string $message): never { self::respond(['error'=>$message],$status); }
    public static function run(): void {
        Auth::start();
        $path=(string)($_GET['path']??'/');$path='/'.trim($path,'/');if($path==='//')$path='/';
        try { if($_SERVER['REQUEST_METHOD']!=='GET')Auth::csrf();Service::dispatch($path); }
        catch(Throwable $e){error_log('[PetTrack] '.$e::class.': '.$e->getMessage());if($e instanceof \PDOException)self::fail(503,'PetTrack could not complete the request. Check the database configuration.');self::fail(500,'PetTrack could not complete the request. Please try again.');}
    }
}
