<?php

namespace App\Http\Middleware;

use App\Support\Localization\LocaleResolver;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SetRequestLocale
{
    public function __construct(private readonly LocaleResolver $resolver) {}

    public function handle(Request $request, Closure $next): Response
    {
        $queryLocale = $request->query('locale');
        $requestedLocale = is_string($queryLocale) ? $queryLocale : null;
        $locale = $this->resolver->resolve(
            requestedLocale: $requestedLocale,
            acceptLanguage: $request->header('Accept-Language'),
        );

        app()->setLocale($locale);

        return $next($request);
    }
}
