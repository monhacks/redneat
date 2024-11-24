; Define Trainer Groups
GYM_LEADER_CLASS_START  equ $10  ; Starting index for Gym Leaders
GYM_LEADER_CLASS_END    equ $1F  ; Ending index for Gym Leaders
ELITE_FOUR_CLASS_START  equ $20  ; Starting index for Elite Four
ELITE_FOUR_CLASS_END    equ $24  ; Ending index for Elite Four

GYM_LEADER_GROUP        equ $01
ELITE_FOUR_GROUP        equ $02

; Define Trainer Classes (Example)
TrainerClasses:
    db $00 ; Youngster
    db $01 ; Lass
    db $02 ; Bug Catcher
    ; ...
    db $10 ; Brock (Gym Leader start)
    db $11 ; Misty
    ; ...
    db $1F ; Giovanni (Gym Leader end)
    db $20 ; Lorelei (Elite Four start)
    db $21 ; Bruno
    db $22 ; Agatha
    db $23 ; Lance
    db $24 ; Champion (Elite Four end)

; Status Effect Definitions
SLEEP_EFFECT  equ $01
POISON_EFFECT equ $02
PARALYZE_EFFECT equ $03
FREEZE_EFFECT equ $04

StatusAilmentMoveEffects:
    db SLEEP_EFFECT
    db POISON_EFFECT
    db PARALYZE_EFFECT
    db FREEZE_EFFECT
    db -1                 ; End of list


CheckTrainerGroup:
    ; Load the current trainer class
    ld a, [wTrainerClass]
    ; Check if Gym Leader
    cp GYM_LEADER_CLASS_START
    jr c, .notGymLeader
    cp GYM_LEADER_CLASS_END + 1
    jr nc, .notGymLeader
    ld a, GYM_LEADER_GROUP
    ret

.notGymLeader:
    ; Check if Elite Four
    ld a, [wTrainerClass]
    cp ELITE_FOUR_CLASS_START
    jr c, .notEliteFour
    cp ELITE_FOUR_CLASS_END + 1
    jr nc, .notEliteFour
    ld a, ELITE_FOUR_GROUP
    ret

.notEliteFour:
    xor a  ; Default to 0 (no group)
    ret

ApplyTrainerGroupLogic:
    ; Determine trainer group and apply corresponding logic
    call CheckTrainerGroup
    cp GYM_LEADER_GROUP
    jr z, .gymLeaderLogic
    cp ELITE_FOUR_GROUP
    jr z, .eliteFourLogic
    ret

.gymLeaderLogic:
    ; Balanced strategy for Gym Leaders
    call EncourageBalancedStrategy
    ret

.eliteFourLogic:
    ; Offensive strategy for Elite Four
    call EncourageOffensiveMoves
    ret

AIEnemyTrainerChooseMoves:
    call Random
    and %00000011         ; 25% chance to pick a random move
    jp z, .useRandomMove  ; Jump to random move selection

    ; Initialize move array
    ld a, $a
    ld hl, wBuffer        ; Temporary buffer for move selection
    ld [hli], a           ; Move 1
    ld [hli], a           ; Move 2
    ld [hli], a           ; Move 3
    ld [hl], a            ; Move 4

    ; Handle disabled moves
    ld a, [wEnemyDisabledMove]
    swap a
    and $f
    jr z, .noMoveDisabled
    ld hl, wBuffer
    dec a
    ld c, a
    ld b, $0
    add hl, bc
    ld [hl], $50          ; Discourage disabled move
.noMoveDisabled:

    ; Apply group-specific logic
    call ApplyTrainerGroupLogic

    ; Filter moves by effectiveness and status
    call FilterMovesByEffectiveness
    call FilterMovesByStatus
    ret

.useRandomMove:
    ld a, [wEnemyMonMoves]
    ld hl, wBuffer
    ld [hl], a
    ret

FilterMovesByEffectiveness:
    ld hl, wBuffer         ; Temp move selection array
    ld de, wEnemyMonMoves  ; Original move list
    ld c, NUM_MOVES

.filterLoop:
    ld a, [de]
    inc de
    and a
    jr z, .nextMove         ; Skip empty slots

    ; Check type effectiveness
    call AIGetTypeEffectiveness
    ld a, [wTypeEffectiveness]
    cp $20
    jr z, .superEffective
    cp $05
    jr c, .notEffective

.superEffective:
    dec [hl]                ; Encourage super-effective moves
    jr .nextMove

.notEffective:
    inc [hl]                ; Discourage ineffective moves

.nextMove:
    inc hl
    dec c
    jr nz, .filterLoop
    ret


FilterMovesByStatus:
    ld hl, wBuffer         ; Temp move selection array
    ld de, wEnemyMonMoves  ; Original move list
    ld b, NUM_MOVES

.checkStatus:
    dec b
    ret z                  ; All moves processed
    inc hl
    ld a, [de]
    and a
    ret z                  ; No more moves
    inc de

    ; Check if player's Pokémon has a status
    ld a, [wBattleMonStatus]
    and a
    jr z, .nextMove         ; Skip if no status condition

    ; Check if move applies a redundant status
    ld a, [wEnemyMoveEffect]
    ld hl, StatusAilmentMoveEffects
    call IsInArray
    jr nc, .nextMove        ; Skip non-status moves

    ; Discourage redundant status effects
    ld a, [wBattleMonStatus]
    cp [hl]
    jr nz, .nextMove
    inc [hl]

.nextMove:
    jr .checkStatus


EncourageBalancedStrategy:
    ld hl, wBuffer
    ld c, NUM_MOVES
.balancedLoop:
    ld a, [hl]
    and a
    jr z, .nextBalancedMove
    dec [hl]               ; Slightly encourage all moves
.nextBalancedMove:
    inc hl
    dec c
    jr nz, .balancedLoop
    ret

EncourageOffensiveMoves:
    ld hl, wBuffer
    ld de, wEnemyMonMoves
    ld c, NUM_MOVES
.offensiveLoop:
    ld a, [de]
    inc de
    and a
    jr z, .nextOffensiveMove
    ld a, [hl]
    dec a                  ; Favor offensive moves
    ld [hl], a
.nextOffensiveMove:
    inc hl
    dec c
    jr nz, .offensiveLoop
    ret



