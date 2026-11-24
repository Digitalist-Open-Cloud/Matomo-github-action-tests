<?php

/**
 * Limits the code coverage in a phpunit.xml of Matomo to one plugin.
 *
 * Usage: php scope_coverage.php <path to phpunit.xml> <plugin name>
 */

[$file, $plugin] = [$argv[1] ?? '', $argv[2] ?? ''];
if (!is_file($file) || !preg_match('/^[a-zA-Z0-9_]+$/', $plugin)) {
    fwrite(STDERR, "Usage: php scope_coverage.php <path to phpunit.xml> <plugin name>\n");
    exit(1);
}

$document = new DOMDocument();
$document->preserveWhiteSpace = false;
$document->formatOutput = true;
if (!$document->load($file)) {
    fwrite(STDERR, "Could not read $file\n");
    exit(1);
}

$directory = function (string $path) use ($document, $plugin): DOMElement {
    $element = $document->createElement('directory', '../../plugins/' . $plugin . $path);
    $element->setAttribute('suffix', '.php');

    return $element;
};
$excluded = $document->createElement('exclude');
foreach (['/tests', '/Test', '/Updates'] as $path) {
    $excluded->appendChild($directory($path));
}

// PHPUnit 9 and later have <coverage>, earlier versions <filter><whitelist>.
$coverage = $document->getElementsByTagName('coverage')->item(0);
$whitelist = $document->getElementsByTagName('whitelist')->item(0);
if ($coverage instanceof DOMElement) {
    foreach (['include', 'exclude'] as $name) {
        foreach (iterator_to_array($coverage->getElementsByTagName($name)) as $element) {
            $coverage->removeChild($element);
        }
    }
    $included = $document->createElement('include');
    $included->appendChild($directory(''));
    $coverage->insertBefore($excluded, $coverage->firstChild);
    $coverage->insertBefore($included, $excluded);
} elseif ($whitelist instanceof DOMElement) {
    while ($whitelist->firstChild) {
        $whitelist->removeChild($whitelist->firstChild);
    }
    $whitelist->appendChild($directory(''));
    $whitelist->appendChild($excluded);
} else {
    // Nothing to limit: the tests run the same without it.
    exit(0);
}

$document->save($file);
