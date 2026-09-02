<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AdminSessionController;

Route::get('/', function () {
    return view('welcome');
});
Route::post('/admin/session', [AdminSessionController::class, 'store'])->middleware('throttle:5,1');
Route::delete('/admin/session', [AdminSessionController::class, 'destroy'])->middleware('auth');
Route::get('/admin/{path?}', fn () => view('admin'))->where('path', '.*');
