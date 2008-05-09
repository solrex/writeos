/* chapter2/2/boot.S

   Author: Wenbo Yang <solrex@gmail.com> <http://solrex.cn>

   This file is part of the source code of book "Write Operating System with
   Free Software". The latest version, see <http://share.solrex.cn/WriteOS/>.

   This file is licensed under the GNU General Public License; either
   version 3 of the License, or (at your option) any later version. */

SECTIONS
{
  . = 0x7c00;
  .text :
  {
    _ftext = .;
  } = 0
}
