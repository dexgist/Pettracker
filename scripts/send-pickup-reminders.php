<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { fwrite(STDERR, "CLI only.\n"); exit(1); }
require dirname(__DIR__).'/server/src/Database.php';
$db=\PetTrack\Database::connection();
$db->beginTransaction();
try {
    $rows=$db->query("SELECT s.id,s.request_id,r.reference_no,p.owner_id,s.pickup_at FROM pickup_dropoff_schedules s JOIN relocation_requests r ON r.id=s.request_id JOIN pets p ON p.id=r.pet_id WHERE s.reminder_sent_at IS NULL AND s.status IN ('scheduled','changed') AND s.pickup_at>NOW() AND s.pickup_at<=DATE_ADD(NOW(),INTERVAL 24 HOUR) FOR UPDATE")->fetchAll();
    $notify=$db->prepare('INSERT INTO notifications(user_id,title,message,record_type,record_id) VALUES(?,?,?,?,?)');
    $mark=$db->prepare('UPDATE pickup_dropoff_schedules SET reminder_sent_at=NOW() WHERE id=? AND reminder_sent_at IS NULL');
    foreach($rows as $row){$notify->execute([(int)$row['owner_id'],'Pickup reminder','Pickup for '.$row['reference_no'].' is scheduled for '.$row['pickup_at'].'.','request',(int)$row['request_id']]);$mark->execute([(int)$row['id']]);}
    $docs=$db->query("SELECT d.id,d.valid_until,p.owner_id,r.reference_no,s.name requirement_name FROM uploaded_documents d JOIN relocation_requests r ON r.id=d.request_id JOIN pets p ON p.id=r.pet_id JOIN request_requirement_snapshots s ON s.id=d.requirement_snapshot_id WHERE d.validity_reminder_sent_at IS NULL AND d.valid_until IS NOT NULL AND d.valid_until<=DATE_ADD(CURDATE(),INTERVAL 30 DAY) AND d.review_status<>'corrections' FOR UPDATE")->fetchAll();
    $notifyDocument=$db->prepare('INSERT INTO notifications(user_id,title,message,record_type,record_id) VALUES(?,?,?,?,?)');
    $markDocument=$db->prepare('UPDATE uploaded_documents SET validity_reminder_sent_at=NOW() WHERE id=? AND validity_reminder_sent_at IS NULL');
    foreach($docs as $doc){$expired=$doc['valid_until']<date('Y-m-d');$message=$expired?'Your '.$doc['requirement_name'].' document for '.$doc['reference_no'].' expired on '.$doc['valid_until'].'. Contact relocation staff about an updated copy.':'Your '.$doc['requirement_name'].' document for '.$doc['reference_no'].' expires on '.$doc['valid_until'].'. Contact relocation staff if a renewed copy is needed.';$notifyDocument->execute([(int)$doc['owner_id'],$expired?'Document expired':'Document expiration reminder',$message,'request',(int)$doc['request_id']]);$markDocument->execute([(int)$doc['id']]);}
    $db->commit();fwrite(STDOUT,count($rows)." pickup reminder(s) and ".count($docs)." document expiration reminder(s) created.\n");
} catch(\Throwable $e) { if($db->inTransaction())$db->rollBack();error_log('[PetTrack reminders] '.$e->getMessage());fwrite(STDERR,"Could not create pickup reminders. Check the protected PHP error log.\n");exit(1); }
