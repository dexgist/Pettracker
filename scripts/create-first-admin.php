<?php
declare(strict_types=1);
// Run only from a trusted command line after importing database/schema.sql.
if (PHP_SAPI !== 'cli') { fwrite(STDERR, "CLI only.\n"); exit(1); }
require dirname(__DIR__).'/server/src/Database.php';
if ($argc !== 3) { fwrite(STDERR, "Usage: php scripts/create-first-admin.php <name> <email>\nSet PETTRACK_INITIAL_ADMIN_PASSWORD to a password of at least 14 characters.\n"); exit(2); }
[$script,$name,$email]=$argv;
$password=(string)(getenv('PETTRACK_INITIAL_ADMIN_PASSWORD') ?: '');
putenv('PETTRACK_INITIAL_ADMIN_PASSWORD');
if (strlen($name)<2 || !filter_var($email,FILTER_VALIDATE_EMAIL) || strlen($password)<14) { fwrite(STDERR,"Enter a valid name and email, and set a password of at least 14 characters in PETTRACK_INITIAL_ADMIN_PASSWORD.\n"); exit(2); }
$db=\PetTrack\Database::connection();
$lock=(int)$db->query("SELECT GET_LOCK('pettrack_first_admin_setup',10)")->fetchColumn();
if($lock!==1){fwrite(STDERR,"Could not safely lock the initial administrator setup. Try again.\n");exit(4);}
try {
    if ((int)$db->query("SELECT COUNT(*) FROM users WHERE role='admin'")->fetchColumn() > 0) { fwrite(STDERR,"An administrator already exists. Create additional administrators from the signed-in administrator dashboard.\n"); exit(3); }
    $db->beginTransaction();
    $q=$db->prepare("INSERT INTO users(name,email,password_hash,role,active,must_change_password) VALUES(?,?,?,'admin',1,0)");
    $q->execute([$name,strtolower($email),password_hash($password,PASSWORD_DEFAULT)]);
    $id=(int)$db->lastInsertId();$q=$db->prepare("INSERT INTO audit_logs(actor_user_id,action,record_type,record_id,outcome,metadata_json) VALUES(?,'initial_admin_created','user',?,'success',JSON_OBJECT('method','cli'))");$q->execute([$id,$id]);
    $db->commit();
} catch(Throwable $e) {
    if($db->inTransaction())$db->rollBack();
    throw $e;
} finally {
    $db->query("SELECT RELEASE_LOCK('pettrack_first_admin_setup')");
}
$password='';fwrite(STDOUT,"Initial administrator created (user ID {$id}).\n");
