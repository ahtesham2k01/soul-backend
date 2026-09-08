<?php

namespace App\Enums\Profile;

enum ReligionNodeType: string
{
    case Religion = 'religion';

    case Belief = 'belief';

    case Sect = 'sect';

    case Tradition = 'tradition';

    case Denomination = 'denomination';

    case SubSect = 'sub_sect';

    case School = 'school';

    case Movement = 'movement';

    case Community = 'community';

    case Caste = 'caste';
}
