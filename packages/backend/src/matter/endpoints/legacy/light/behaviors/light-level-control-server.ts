import type {
  HomeAssistantEntityState,
  LightDeviceAttributes,
} from "@home-assistant-matter-hub/common";
import {
  type LevelControlConfig,
  LevelControlServer,
} from "../../../../behaviors/level-control-server.js";

const config: LevelControlConfig = {
  getValuePercent: (state: HomeAssistantEntityState<LightDeviceAttributes>) => {
    const brightness = state.attributes.brightness;
    let result: number;
    if (brightness != null) {
      result = brightness / 255;
    } else {
      // Default to 1 (100%) when brightness is null to avoid Alexa compatibility issues
      result = 1;
    }
    return result;
  },
  moveToLevelPercent: (brightnessPercent) => ({
    action: "light.turn_on",
    data: {
      brightness: Math.round(brightnessPercent * 255),
    },
  }),
};

export const LightLevelControlServer = LevelControlServer(config).with(
  "OnOff",
  "Lighting",
);
