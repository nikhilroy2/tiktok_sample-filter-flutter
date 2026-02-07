<?php
// backend/api/db.php

// Supabase Connection Details (Transaction Pooler - IPv4 Compatible)
$host = 'aws-1-ap-southeast-2.pooler.supabase.com';
$db   = 'postgres';
$user = 'postgres.bbjlueyirkojoqlsvuzh';
$port = '6543';
$pass = 'Ncx3ZDL723k3h2ER'; // <--- REPLACE THIS with your actual password

$dsn = "pgsql:host=$host;port=$port;dbname=$db";

try {
    $pdo = new PDO($dsn, $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Create tables if they don't exist (PostgreSQL syntax)
    $pdo->exec("CREATE TABLE IF NOT EXISTS videos (
        id SERIAL PRIMARY KEY,
        filename TEXT NOT NULL,
        filepath TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
} catch (PDOException $e) {
    die("Could not connect to Supabase: " . $e->getMessage());
}
?>
