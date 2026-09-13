<?php

namespace App\Support\Operations;

class PrometheusHealthFormatter
{
    public function format(array $snapshot): string
    {
        $lines = [
            '# HELP soul_operational_health Overall operational health (1 healthy, 0 unhealthy).',
            '# TYPE soul_operational_health gauge',
            'soul_operational_health '.($snapshot['status'] === 'healthy' ? 1 : 0),
        ];

        foreach ($snapshot['metrics'] as $name => $value) {
            $metric = 'soul_'.preg_replace('/[^a-z0-9_]/', '_', strtolower($name));
            $lines[] = '# TYPE '.$metric.' gauge';
            $lines[] = $metric.' '.(int) $value;
        }

        $lines[] = '# HELP soul_operational_warning Active operational warning by stable code and severity.';
        $lines[] = '# TYPE soul_operational_warning gauge';
        foreach ($snapshot['warnings'] as $warning) {
            $code = addcslashes($warning['code'], "\\\"\n");
            $severity = addcslashes($warning['severity'], "\\\"\n");
            $lines[] = 'soul_operational_warning{code="'.$code.'",severity="'.$severity.'"} 1';
        }

        return implode("\n", $lines)."\n";
    }
}
