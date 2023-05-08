open Common

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)
(* Gather Semgrep app related code.
 *
 * TODO? split some code in Auth.ml?
 *)

(*****************************************************************************)
(* Entry points *)
(*****************************************************************************)

(* from auth.py *)
let get_deployment_id () =
  match Semgrep_settings.((get ()).api_token) with
  | None -> None
  | Some token -> (
      match
        Http_helpers.get
          ~headers:[ ("authorization", "Bearer " ^ token) ]
          (Uri.with_path Semgrep_envvars.env.semgrep_url
             "api/agent/deployments/current")
      with
      | Error msg ->
          Logs.debug (fun m -> m "error while retrieving deployment: %s" msg);
          None
      | Ok json -> (
          try
            match Yojson.Basic.from_string json with
            | `Assoc e -> (
                match List.assoc_opt "deployment" e with
                | Some (`Assoc e) -> (
                    match List.assoc_opt "id" e with
                    | Some (`Int i) -> Some i
                    | _else -> None)
                | _else -> None)
            | _else -> None
          with
          | Yojson.Json_error msg ->
              Logs.debug (fun m -> m "failed to parse json %s: %s" msg json);
              None))

(* from auth.py *)
let get_deployment_from_token token =
  match
    Http_helpers.get
      ~headers:[ ("authorization", "Bearer " ^ token) ]
      (Uri.with_path Semgrep_envvars.env.semgrep_url
         "api/agent/deployments/current")
  with
  | Error msg ->
      Logs.debug (fun m -> m "error while retrieving deployment: %s" msg);
      None
  | Ok json -> (
      try
        match Yojson.Basic.from_string json with
        | `Assoc e -> (
            match List.assoc_opt "deployment" e with
            | Some (`Assoc e) -> (
                match List.assoc_opt "name" e with
                | Some (`String s) -> Some s
                | _else -> None)
            | _else -> None)
        | _else -> None
      with
      | Yojson.Json_error msg ->
          Logs.debug (fun m -> m "failed to parse json %s: %s" msg json);
          None)

let default_semgrep_app_config_url = "api/agent/deployments/scans/config"

let url_for_policy () =
  match get_deployment_id () with
  | None ->
      Error.abort
        (spf "Invalid API Key. Run `semgrep logout` and `semgrep login` again.")
  | Some _deployment_id -> (
      match Sys.getenv_opt "SEMGREP_REPO_NAME" with
      | None ->
          Error.abort
            (spf
               "Need to set env var SEMGREP_REPO_NAME to use `--config policy`")
      | Some repo_name ->
          Uri.(
            add_query_params'
              (with_path Semgrep_envvars.env.semgrep_url
                 default_semgrep_app_config_url)
              [
                ("sca", "False");
                ("dry_run", "True");
                ("full_scan", "True");
                ("repo_name", repo_name);
                ("semgrep_version", Version.version);
              ]))