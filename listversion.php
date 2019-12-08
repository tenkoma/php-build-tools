#!/usr/bin/env php
<?php
declare(strict_types=1);
/**
 * usage: php listversion.php [--filter stable|minor-head] [--oldest-version version] [--definitions-path path]
 */
class PhpVersion
{
    const VERSION_PATTERN = '/(?P<major>\d+)\.(?P<minor>\d+)\.(?P<point>\d+)/';
    public static function getMinorVersion(string $version)
    {
        preg_match(self::VERSION_PATTERN, $version, $matches);
        return sprintf('%s.%s', $matches['major'], $matches['minor']);
    }

    public static function isStable(string $version)
    {
        return preg_match(self::VERSION_PATTERN, $version) === 1;
    }
}

$argvOptions = getopt('', ['filter:', 'oldest-version:', 'definitions-path:']);
$options = [
    'filter' => !empty($argvOptions['filter']) ? $argvOptions['filter'] : 'minor-head',
    'oldest_version' => !empty($argvOptions['oldest-version']) ? $argvOptions['oldest-version'] : '5.5.0',
    'definitions_path' => !empty($argvOptions['definitions-path'])
        ? $argvOptions['definitions-path']
        : getenv('HOME') . "/src/github.com/php-build/php-build/share/php-build/definitions/",
];

$definitionsIter = new DirectoryIterator($options['definitions_path']);
$versions = [];
foreach ($definitionsIter as $definition) {
    if ($definition->isDot()) {
        continue;
    }
    $version = $definition->getFilename();
    if (! PhpVersion::isStable($version)) {
        continue;
    }
    if (version_compare($version, $options['oldest_version'], '<')) {
        continue;
    }
    if ($options['filter'] === 'minor-head') {
        $minorVersion = PhpVersion::getMinorVersion($version);
        if (!isset($versions[$minorVersion])
            || version_compare($version, $versions[$minorVersion], '>')) {
            $versions[$minorVersion] = $version;
        }
    } else {
        $versions[] = $version;
    }
}
echo implode("\n", $versions) . PHP_EOL;