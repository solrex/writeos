/* chapter3/6/solrex_x86_dos.ld

   Author: Wenbo Yang <http://yangwenbo.com>

   This file is part of the source code of book "Write Your Own OS with Free
   and Open Source Software". Homepage @ <https://github.com/solrex/writeos>.

   This file is licensed under the GNU General Public License; either
   version 3 of the License, or (at your option) any later version. */

SECTIONS
{
  . = 0x0100;
  .text :
  {
    _ftext = .;
  } = 0
}
