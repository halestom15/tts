function onload(save_state)
    self.interactable = false

    assetButton = getObjectFromGUID("406a41")
    assetButton.createButton({
            click_function = "removeSuppression", function_owner = self, label = "", position = {0, 0.65, 0}, scale = {1, 1, 0.7}, width = 1500, height = 2000, font_size = 400, color = {0.7573, 0.7573, 0.7573, 0.01}, font_color = {0, 0, 0, 100}, tooltip = "Remove one suppression from each suppression token in the Battlefield"
    })
end

-- Suppression tokens are counters (see !/TokenCounters in the Global): one
-- off every token and stack in the battlefield zone, a token at one goes back.
function removeSuppression()
    assetButton.AssetBundle.playTriggerEffect(0)
    Global.call("gRemoveOneSuppression", {})
end
