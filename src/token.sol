// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TST") {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Minta 1 millón de tokens
    }

    // Función mint pública para acuñar más tokens
    function mint(address to, uint256 amount) public {
        _mint(to, amount); // Llamamos a la función interna _mint
    }
}
