import {
  type CoverDeviceAttributes,
  CoverDeviceState,
  type HomeAssistantEntityState,
} from "@home-assistant-matter-hub/common";
import type { Agent } from "@matter/main";
import { WindowCovering } from "@matter/main/clusters";
import { BridgeDataProvider } from "../../../../../services/bridges/bridge-data-provider.js";
import {
  type WindowCoveringConfig,
  WindowCoveringServer,
} from "../../../../behaviors/window-covering-server.js";

const attributes = (entity: HomeAssistantEntityState) =>
  <CoverDeviceAttributes>entity.attributes;

const adjustPosition = (position: number, agent: Agent) => {
  const { featureFlags } = agent.env.get(BridgeDataProvider);
  if (position == null) {
    return null;
  }
  let percentValue = position;
  const shouldInvert = featureFlags?.coverDoNotInvertPercentage !== true;
  if (shouldInvert) {
    percentValue = 100 - percentValue;
    console.log(`[CoverWindowCovering] adjustPosition: inverted ${position} → ${percentValue}`);
  } else {
    console.log(`[CoverWindowCovering] adjustPosition: not inverting ${position}`);
  }
  return percentValue;
};

const config: WindowCoveringConfig = {
  getCurrentLiftPosition: (entity, agent) => {
    let position = attributes(entity).current_position;
    if (position == null) {
      const coverState = entity.state as CoverDeviceState;
      position =
        coverState === CoverDeviceState.closed
          ? 100
          : coverState === CoverDeviceState.open
            ? 0
            : undefined;
      console.log(`[CoverWindowCovering] getCurrentLiftPosition: no current_position, using state: ${coverState} → position ${position}`);
    } else {
      console.log(`[CoverWindowCovering] getCurrentLiftPosition: got current_position from HA: ${position}`);
    }
    const result = position == null ? null : adjustPosition(position, agent);
    console.log(`[CoverWindowCovering] [STATUS] getCurrentLiftPosition: HA=${position} → reporting to Alexa=${result}%`);
    return result;
  },
  getCurrentTiltPosition: (entity, agent) => {
    let position = attributes(entity).current_tilt_position;
    if (position == null) {
      const coverState = entity.state as CoverDeviceState;
      position =
        coverState === CoverDeviceState.closed
          ? 100
          : coverState === CoverDeviceState.open
            ? 0
            : undefined;
    }
    return position == null ? null : adjustPosition(position, agent);
  },
  getMovementStatus: (entity) => {
    const coverState = entity.state as CoverDeviceState;
    return coverState === CoverDeviceState.opening
      ? WindowCovering.MovementStatus.Opening
      : coverState === CoverDeviceState.closing
        ? WindowCovering.MovementStatus.Closing
        : WindowCovering.MovementStatus.Stopped;
  },

  stopCover: () => ({ action: "cover.stop_cover" }),

  openCoverLift: () => ({ action: "cover.open_cover" }),
  closeCoverLift: () => ({ action: "cover.close_cover" }),
  setLiftPosition: (position, agent) => {
    const adjusted = adjustPosition(position, agent);
    console.log(`[CoverWindowCovering] [COMMAND] setLiftPosition: Alexa sent=${position} → sending to HA=${adjusted}`);
    return {
      action: "cover.set_cover_position",
      data: { position: adjusted },
    };
  },

  openCoverTilt: () => ({ action: "cover.open_cover_tilt" }),
  closeCoverTilt: () => ({ action: "cover.close_cover_tilt" }),
  setTiltPosition: (position, agent) => {
    const adjusted = adjustPosition(position, agent);
    console.log(`[CoverWindowCovering] [COMMAND] setTiltPosition: Alexa sent=${position} → sending to HA=${adjusted}`);
    return {
      action: "cover.set_cover_tilt_position",
      data: { tilt_position: adjusted },
    };
  },
};

export const CoverWindowCoveringServer = WindowCoveringServer(config);
