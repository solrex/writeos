/* chapter2/2/loader.S

   Author: Wenbo Yang <http://yangwenbo.com>

   This file is part of the source code of book "Write Your Own OS with Free
   and Open Source Software". Homepage @ <https://github.com/solrex/writeos>.

   This file is licensed under the GNU General Public License; either
   version 3 of the License, or (at your option) any later version. */

.code16
.text
	mov		$0xb800,%ax
	mov     %ax,%gs
	mov		$0xf,%ah
	mov		$'L',%al
	mov		%ax,%gs:((80*0+39)*2)
	jmp		.
