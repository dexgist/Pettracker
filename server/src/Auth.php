<?php
declare(strict_types=1);
namespace PetTrack;
final class Auth {
    public static function start(): void {
        $https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https');
        session_name('pettrack_session');
        session_set_cookie_params(['lifetime'=>0,'path'=>'/','secure'=>$https,'httponly'=>true,'samesite'=>'Lax']);
        if (session_status() !== PHP_SESSION_ACTIVE) session_start();
        if (isset($_SESSION['last_activity']) && time() - (int)$_SESSION['last_activity'] > 3600) { self::logout(); session_start(); }
        if (!isset($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(32));
        $_SESSION['last_activity'] = time();
    }
    public static function user(): ?array {
        if (!isset($_SESSION['user'])) return null;
        $q = Database::connection()->prepare('SELECT id,name,email,role,active,must_change_password FROM users WHERE id=?');
        $q->execute([$_SESSION['user']['id']]); $fresh = $q->fetch();
        if (!$fresh || !(bool)$fresh['active']) { self::logout(); return null; }
        $_SESSION['user'] = ['id'=>(int)$fresh['id'],'name'=>$fresh['name'],'email'=>$fresh['email'],'role'=>$fresh['role'],'must_change_password'=>(bool)$fresh['must_change_password']];
        return $_SESSION['user'];
    }
    public static function requireUser(): array { $u = self::user(); if (!$u) Http::fail(401, 'Please sign in to continue.'); return $u; }
    public static function requireRole(string ...$roles): array { $u=self::requireUser(); if (!in_array($u['role'],$roles,true)) Http::fail(403,'You do not have permission to perform this action.'); return $u; }
    public static function csrf(): void { if ($_SERVER['REQUEST_METHOD'] !== 'GET' && !hash_equals((string)($_SESSION['csrf']??''),(string)($_SERVER['HTTP_X_CSRF_TOKEN']??''))) Http::fail(419,'Your session expired. Refresh and try again.'); }
    public static function login(array $row): array { session_regenerate_id(true); $_SESSION['csrf']=bin2hex(random_bytes(32)); $_SESSION['user']=['id'=>(int)$row['id'],'name'=>$row['name'],'email'=>$row['email'],'role'=>$row['role'],'must_change_password'=>(bool)($row['must_change_password']??false)]; $_SESSION['last_activity']=time(); return $_SESSION['user']; }
    public static function logout(): void { $_SESSION=[]; if (ini_get('session.use_cookies')) { $p=session_get_cookie_params(); setcookie(session_name(),'',time()-42000,$p['path'],$p['domain']??'',(bool)$p['secure'],(bool)$p['httponly']); } session_destroy(); }
}
