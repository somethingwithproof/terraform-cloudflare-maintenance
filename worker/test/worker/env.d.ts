// Types for the cloudflare:test and cloudflare:workers modules, which
// `wrangler types` would otherwise generate: the bindings in wrangler.json
// and the Worker's main module.
import type { Env as WorkerEnv } from "../../src/index";

declare global {
  namespace Cloudflare {
    // Declaration merging needs an interface, so it cannot be a type alias.
    // eslint-disable-next-line @typescript-eslint/no-empty-object-type
    interface Env extends WorkerEnv {}
    interface GlobalProps {
      mainModule: typeof import("../../src/index");
    }
  }
}
