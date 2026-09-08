<?php
namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
class AdminSessionController extends Controller {
 public function store(Request $request): RedirectResponse { $v=$request->validate(['email'=>['required','email'],'password'=>['required','string']]); if(!Auth::attempt($v,true)||Auth::user()?->admin_role===null){ Auth::logout(); return back()->withErrors(['email'=>'Invalid admin credentials.']); } $request->session()->regenerate(); return redirect('/admin'); }
 public function destroy(Request $request): RedirectResponse { Auth::logout(); $request->session()->invalidate(); $request->session()->regenerateToken(); return redirect('/admin'); }
}
