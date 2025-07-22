StatEffects = {}

local function GetStatEffect(value, effectsTable)
    if type(effectsTable) ~= 'table' then return nil end

    local matchedThreshold = 0
    local matchedEffect = nil

    for threshold, effect in pairs(effectsTable) do
        if value >= threshold and threshold > matchedThreshold then
            matchedThreshold = threshold
            matchedEffect = effect
        end
    end

    return matchedEffect
end

local function ApplyStaminaEffect(stamina, playerId)
    local staminaEffect = GetStatEffect(stamina, Config.StaminaEffects)
    if staminaEffect then
        SetRunSprintMultiplierForPlayer(playerId, staminaEffect.sprintMultiplier)
        if staminaEffect.staminaRegen then
            RestorePlayerStamina(playerId, staminaEffect.staminaRegen)
        end
    else
        SetRunSprintMultiplierForPlayer(playerId, 1.0)
    end
end

local function ApplyStrengthEffect(strength, playerId)
    local strengthEffect = GetStatEffect(strength, Config.StrengthEffects)
    if strengthEffect then
        SetPlayerMeleeWeaponDamageModifier(playerId, strengthEffect.meleeDamage)

        if strengthEffect.punchForce then
            local punchForce = strengthEffect.punchForce
            SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), punchForce)
        end
    else
        SetPlayerMeleeWeaponDamageModifier(playerId, 1.0)
    end
end

exports('GetStatEffect', GetStatEffect)
exports('ApplyStrengthEffect', ApplyStrengthEffect)
exports('ApplyStaminaEffect', ApplyStaminaEffect)