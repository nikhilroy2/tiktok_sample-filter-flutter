<?php
// backend/api/upload.php

header('Content-Type: application/json');
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_FILES['video']) && $_FILES['video']['error'] === UPLOAD_ERR_OK) {
        $upload_dir = __DIR__ . '/../uploads/';
        if (!is_dir($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }

        $filename = uniqid('vid_') . '_' . basename($_FILES['video']['name']);
        $target_file = $upload_dir . $filename;

        if (move_uploaded_file($_FILES['video']['tmp_path'], $target_file)) {
            // Save to database
            $stmt = $pdo->prepare("INSERT INTO videos (filename, filepath) VALUES (?, ?)");
            $stmt->execute([$filename, $target_file]);

            echo json_encode([
                'success' => true,
                'message' => 'Video uploaded successfully',
                'video_id' => $pdo->lastInsertId()
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to move uploaded file']);
        }
    } else {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'No video file uploaded or upload error']);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}
?>
