import { OnOffServer } from "../../../../behaviors/on-off-server.js";
import { LevelControlServerBase } from "../../../../behaviors/level-control-server.js";

export const LightOnOffServer = OnOffServer({
  turnOn: (entity, agent) => {
    // Get onLevel from LevelControl behavior if it exists
    const levelControl = agent.get(LevelControlServerBase);
    const onLevel = levelControl?.state?.onLevel;
    
    // Convert Matter level (1-254) to HA brightness (0-255)
    const brightness = onLevel != null ? Math.round(((onLevel - 1) / 253) * 255) : undefined;
    
    return {
      action: "light.turn_on",
      ...(brightness != null && { data: { brightness } }),
    };
  },
  turnOff: () => ({
    action: "light.turn_off",
  }),
  isOn: (e) => {
    const isOn = e.state === "on";
    return isOn;
  },
}).with("Lighting");