# properly checks valid repository 

    Code
      path <- "/nonexistent/dp"
      dp_deploy(project_path = path)
    Condition
      Error in `dp_deploy()`:
      ! project_path, /nonexistent/dp, does not point to a valid dp project. Make sure project path is set up with dp_init Run :dp_repository_check

