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
  function warning(message) {
    core.warning(message);
    summaryRows.push(["ℹ️", message]);
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

  return {
    notice,
    warning,
    failure,
    writeSummary,
  };
};