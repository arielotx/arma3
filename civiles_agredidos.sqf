/*
    Script: Civiles Reactivos (3 muertes)
    Descripción: Los civiles se arman después de matar a 3 civiles
    Uso: Ejecutar en init.sqf
*/

// Variable global para contar civiles muertos
if (isNil "civilesKillCount") then {
    civilesKillCount = 0;
};

// Función para armar civiles
fn_armarCivil = {
    params ["_civil"];
    
    // Verificar que aún es civil
    if (side _civil != civilian) exitWith {};
    
    // Array de armas disponibles para civiles
    _armasDisponibles = [
        "hgun_Pistol_heavy_02_F",
        "hgun_ACPC2_F",
        "hgun_Rook40_F",
        "SMG_02_F",
        "hgun_PDW2000_F"
    ];
    
    // Seleccionar arma aleatoria
    _arma = selectRandom _armasDisponibles;
    
    // Remover arma actual y darle nueva arma
    removeAllWeapons _civil;
    _civil addMagazine [getArray (configFile >> "CfgWeapons" >> _arma >> "magazines") select 0, 4];
    _civil addWeapon _arma;
    
    // Cambiar a lado enemigo
    [_civil] joinSilent grpNull;
    _grupoHostil = createGroup east;
    [_civil] joinSilent _grupoHostil;
    
    // Hacer que el civil sea agresivo
    _civil setBehaviour "COMBAT";
    _civil setCombatMode "RED";
};

// Función para armar a todos los civiles del mapa
fn_armarTodosCiviles = {
    {
        if (side _x == civilian && alive _x) then {
            [_x] call fn_armarCivil;
        };
    } forEach allUnits;
    
    // Mensajes de advertencia
    titleText ["¡Has matado a 3 civiles! ¡Todos se están armando contra ti!", "PLAIN DOWN"];
    systemChat "ADVERTENCIA: Los civiles se han vuelto hostiles";
    playSound "alarm";
};

// Función principal para monitorear civiles
fn_monitoreoCiviles = {
    params ["_civil"];
    
    _civil addEventHandler ["Killed", {
        params ["_unit", "_asesino"];
        
        // Verificar que el asesino es el jugador o su grupo
        if (isPlayer _asesino || {_asesino in units group player}) then {
            // Incrementar contador
            civilesKillCount = civilesKillCount + 1;
            
            // Mensaje con el contador
            systemChat format ["Civiles muertos: %1/3", civilesKillCount];
            
            // Si llegamos a 3, armar a todos los civiles
            if (civilesKillCount >= 3) then {
                [] call fn_armarTodosCiviles;
            };
        };
    }];
};

// APLICAR A TODOS LOS CIVILES EN EL MAPA
{
    if (side _x == civilian) then {
        [_x] call fn_monitoreoCiviles;
    };
} forEach allUnits;

// Monitorear nuevos civiles que aparezcan
addMissionEventHandler ["EntityCreated", {
    params ["_entidad"];
    
    if (_entidad isKindOf "CAManBase" && side _entidad == civilian) then {
        [_entidad] call fn_monitoreoCiviles;
    };
}];

hint "Sistema de civiles reactivos activado\nLímite: 3 civiles muertos";
