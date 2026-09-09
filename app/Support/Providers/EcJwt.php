<?php

namespace App\Support\Providers;

use RuntimeException;

final class EcJwt
{
    /** @param array<string,mixed> $header @param array<string,mixed> $claims */
    public static function sign(array $header, array $claims, string $privateKey): string
    {
        $encode = static fn (string $value): string => rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
        $head = $encode(json_encode($header, JSON_THROW_ON_ERROR));
        $body = $encode(json_encode($claims, JSON_THROW_ON_ERROR));
        if (! openssl_sign($head.'.'.$body, $der, $privateKey, OPENSSL_ALGO_SHA256)) throw new RuntimeException('Provider token signing failed.');
        return $head.'.'.$body.'.'.$encode(self::derToJose($der));
    }

    private static function derToJose(string $der): string
    {
        $offset = 0;
        if (ord($der[$offset++]) !== 0x30) throw new RuntimeException('Invalid ECDSA signature.');
        self::readLength($der, $offset);
        if (ord($der[$offset++]) !== 0x02) throw new RuntimeException('Invalid ECDSA signature.');
        $r = substr($der, $offset, self::readLength($der, $offset)); $offset += strlen($r);
        if (ord($der[$offset++]) !== 0x02) throw new RuntimeException('Invalid ECDSA signature.');
        $s = substr($der, $offset, self::readLength($der, $offset));
        return str_pad(ltrim($r, "\0"), 32, "\0", STR_PAD_LEFT).str_pad(ltrim($s, "\0"), 32, "\0", STR_PAD_LEFT);
    }

    private static function readLength(string $value, int &$offset): int
    {
        $length = ord($value[$offset++]);
        if (($length & 0x80) === 0) return $length;
        $bytes = $length & 0x7f; $length = 0;
        while ($bytes-- > 0) $length = ($length << 8) | ord($value[$offset++]);
        return $length;
    }
}
