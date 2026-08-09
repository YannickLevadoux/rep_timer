module.exports = function(core) {

  const summaryRows = [];

  /**
   * Add a success message to the logs and the Step Summary.
   */
  function notice(message) {
    core.notice(message);
    summaryRows.push(["✅", message]);
  }

  /**
   * Add an informational message to the logs and the Step Summary.
   */
  function info(message) {
    core.info(message);
    summaryRows.push(["\u2139\uFE0F", message]);
  }

  /**
   * Add a warning message to the logs and the Step Summary.
   */
  function warning(message) {
    core.warning(message);
    summaryRows.push(["\u26A0\uFE0F", message]);
  }

  /**
   * Add an error message to the logs and the Step Summary.
   */
  function failure(message) {
    core.error(message);
    summaryRows.push(["❌", message]);
  }

  /**
   * Write the Step Summary.
   */
  async function writeSummary(title) {
    await core.summary
      .addHeading(title)
      .addTable([
        [
          { data: "Status", header: true },
          { data: "Action", header: true }
        ],
        ...summaryRows.map(([status, action]) => [status, action])
      ])
      .write();

    summaryRows.length = 0;
  }

  /**
   * Write an informational report for large source files.
   */
  async function writeFileLengthSummary(files) {
    const ranges = [
      {
        title: "Plus de 300 lignes",
        includes: lines => lines > 300,
      },
      {
        title: "Entre 250 et 300 lignes",
        includes: lines => lines >= 250 && lines <= 300,
      },
      {
        title: "Entre 200 et 249 lignes",
        includes: lines => lines >= 200 && lines <= 249,
      },
    ];

    core.summary
      .addHeading("Longueur des fichiers — lib/")
      .addRaw("Nombre de lignes physiques, commentaires et lignes vides compris.")
      .addEOL();

    for (const range of ranges) {
      const matchingFiles = files
        .filter(file => range.includes(file.lines))
        .sort((left, right) => right.lines - left.lines || left.path.localeCompare(right.path));

      core.summary
        .addHeading(`${range.title} (${matchingFiles.length})`, 2)
        .addTable([
          [
            { data: "Lignes", header: true },
            { data: "Fichier", header: true },
          ],
          ...(matchingFiles.length > 0
            ? matchingFiles.map(file => [String(file.lines), file.path])
            : [["—", "Aucun fichier"]]),
        ]);
    }

    await core.summary.write();
  }

  return {
    notice,
    info,
    warning,
    failure,
    writeSummary,
    writeFileLengthSummary,
  };
};
